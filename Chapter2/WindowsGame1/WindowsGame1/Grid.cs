#region Using Statements
using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
#endregion

namespace VTFTutorial
{
    /// <summary>
    /// This is a game component that implements IUpdateable.
    /// </summary>
    public class Grid
    {
        public Grid(Game game)
        {
            this.game = game;
        }
        Game game;

        GraphicsDevice device;
        VertexBuffer vb;
        IndexBuffer ib;
        VertexPositionNormalTexture[] vertices = new VertexPositionNormalTexture[4];
        int[] indices = new int[6];

//        VertexDeclaration vertexDecl;

        private float cellSize = 10;

        public float CellSize
        {
            get { return cellSize; }
            set { cellSize = value; }
        }

        private short dimension = 128;

        public short Dimension
        {
            get { return dimension; }
            set { dimension = value; }
        }


        public void GenerateStructures()
        {

            vertices = new VertexPositionNormalTexture[(dimension + 1) * (dimension + 1)];
            indices = new int[dimension * dimension * 6];
            for (int i = 0; i < dimension + 1; i++)
            {
                for (int j = 0; j < dimension + 1; j++)
                {
                    VertexPositionNormalTexture vert = new VertexPositionNormalTexture();
                    vert.Position = new Vector3((i - dimension / 2.0f) * cellSize, 0, (j - dimension / 2.0f) * cellSize);
                    vert.Normal = Vector3.Up;
                    vert.TextureCoordinate = new Vector2((float)i / dimension, (float)j / dimension);
                    vertices[i * (dimension + 1) + j] = vert;

                    
                }
            }

            for (int i = 0; i < dimension; i++)
            {
                for (int j = 0; j < dimension; j++)
                {
                    indices[6 * (i * dimension + j)] = (i * (dimension + 1) + j);
                    indices[6 * (i * dimension + j) + 1] = (i * (dimension + 1) + j + 1);
                    indices[6 * (i * dimension + j) + 2] = ((i + 1) * (dimension + 1) + j + 1);

                    indices[6 * (i * dimension + j) + 3] = (i * (dimension + 1) + j);
                    indices[6 * (i * dimension + j) + 4] = ((i + 1) * (dimension + 1) + j + 1);
                    indices[6 * (i * dimension + j) + 5] = ((i + 1) * (dimension + 1) + j);
                }

            }

        }

        public void Draw()
        {

            IGraphicsDeviceService igs = (IGraphicsDeviceService)game.Services.GetService(typeof(IGraphicsDeviceService));
            device = igs.GraphicsDevice;

            DepthStencilState dss = new DepthStencilState();
            dss.DepthBufferEnable = true;
            dss.DepthBufferFunction = CompareFunction.LessEqual;
            dss.DepthBufferWriteEnable = true;
            
            
            RasterizerState rs = new RasterizerState();
            rs.CullMode = CullMode.CullClockwiseFace;
            rs.FillMode = FillMode.Solid;

            device.RasterizerState = rs;
            device.DepthStencilState = dss;

            device.SetVertexBuffer(vb);


            device.Indices = ib;
            device.DrawIndexedPrimitives(PrimitiveType.TriangleList, 0, 0, (dimension + 1) * (dimension + 1), 0, 2 * dimension * dimension);

        }

        public void LoadContent()
        {

            GenerateStructures();

            IGraphicsDeviceService igs = (IGraphicsDeviceService)game.Services.GetService(typeof(IGraphicsDeviceService));
            device = igs.GraphicsDevice;

            vb = new VertexBuffer(device, typeof(VertexPositionNormalTexture), (dimension + 1) * (dimension + 1), BufferUsage.None);
            ib = new IndexBuffer(device, IndexElementSize.ThirtyTwoBits, dimension * dimension * 6, BufferUsage.None);
            //vb = new VertexBuffer(device, (dimension + 1) * (dimension + 1) * VertexPositionNormalTexture.SizeInBytes, ResourceUsage.None, ResourceManagementMode.Automatic);
            //ib = new IndexBuffer(device, 6 * dimension * dimension * sizeof(int), ResourceUsage.None, ResourceManagementMode.Automatic, IndexElementSize.ThirtyTwoBits);
            vb.SetData<VertexPositionNormalTexture>(vertices);

            ib.SetData<int>(indices);

            

            //vertexDecl = new VertexDeclaration(device, VertexPositionNormalTexture.VertexElements);
        }
    }
}


